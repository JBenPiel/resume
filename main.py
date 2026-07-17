import re
import shutil
from pathlib import Path

import click
import jinja2
import markdown
import yaml
from markupsafe import Markup

defaults = {'labels': None}


def read_yaml(filename):
    """Read YAML file and return dictionary data."""
    with Path(filename).open(encoding='utf-8') as f:
        return yaml.safe_load(f) or {}


def render_template(template_path, context):
    """Render template with provided variables."""
    template = jinja2.Environment(
        autoescape=jinja2.select_autoescape(['html', 'xml']),
    ).from_string(template_path.read_text(encoding='utf-8'))
    return template.render(**context)


def copy_static_data(theme_dir, output_dir):
    """Copy theme directory contents, ignoring Jinja template files."""
    shutil.copytree(
        theme_dir,
        output_dir,
        ignore=lambda src, names: [name for name in names if name.endswith('.jinja2')],
    )


def clean(output_dir):
    """Remove the output directory."""
    shutil.rmtree(output_dir, ignore_errors=True)


def build(data, config):
    """Build the output directory with rendered templates and static files."""
    theme_dir = Path('themes') / config.get('theme', 'simple')
    output_dir = Path(config.get('output_dir', 'build'))
    clean(output_dir)
    copy_static_data(theme_dir, output_dir)

    class Helpers:
        @staticmethod
        def md(text):
            """
            Process text as markdown and remove surrounding '<p>' tags for
            simple flat text if possible.
            """
            html = markdown.markdown(text or '', output_format='html5')
            return Markup(re.sub(r'^<p>(.*)</p>$', r'\1', html, flags=re.DOTALL))

    context = {**defaults, **data, 'config': config, 'h': Helpers()}
    for template_path in theme_dir.glob('*.jinja2'):
        html = render_template(template_path, context)
        output_path = output_dir / template_path.with_suffix('.html').name
        output_path.write_text(html, encoding='utf-8')


def make_html(config, data):
    """Generate static HTML build of the resume."""
    build(data, config)


def make_pdf(config, data):
    """Generate PDF from the rendered HTML."""
    from weasyprint import HTML

    output_dir = Path(config.get('output_dir', 'build'))
    HTML(
        output_dir / 'index.html',
        base_url=Path('themes') / config['theme'],
    ).write_pdf(output_dir / config.get('pdf_file', 'resume.pdf'))


@click.command()
@click.argument('resume_file', type=click.Path(exists=True))
@click.option('-o', '--output_dir', default='build', help='Output directory for the build files.')
@click.option('-f', '--format', 'build_format', default='html', type=click.Choice(['html', 'pdf']), help='Build format.')
@click.option('-t', '--theme', help='Name of the theme to use.')
def main(resume_file, output_dir, build_format, theme):
    """Generate HTML or PDF resume from YAML file."""
    resume_data = read_yaml(resume_file)
    resume_config = resume_data.get('config', {})
    config = {
        **resume_config,
        'output_dir': output_dir,
        'theme': theme or resume_config.get('theme', 'simple'),
    }
    {'html': make_html, 'pdf': make_pdf}[build_format](config, resume_data)


if __name__ == '__main__':
    main()
