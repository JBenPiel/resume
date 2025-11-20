import os
import re
import yaml
import shutil
import click
import jinja2
import markdown
from weasyprint import HTML

defaults = {'labels': None}

def read_yaml(filename):
    """Read YAML file and return dictionary data."""
    with open(filename, 'rt') as f:
        return yaml.safe_load(f)

def render_template(tpl_path, vars):
    """Render template with provided variables."""
    with open(tpl_path, 'rt') as f:
        return jinja2.Template(f.read()).render(**vars)

def copy_static_data(theme_dir, output_dir):
    """Copy theme directory contents, ignoring Jinja template files."""
    shutil.copytree(theme_dir, output_dir, ignore=lambda src, names: [n for n in names if n.endswith('.jinja2')])

def clean(output_dir):
    """Remove the output directory."""
    shutil.rmtree(output_dir, ignore_errors=True)

def build(data, config):
    """Build the output directory with rendered templates and static files."""
    theme_dir = os.path.join('themes', config.get('theme', 'simple'))
    output_dir = config.get('output_dir', 'build')
    clean(output_dir)
    copy_static_data(theme_dir, output_dir)

    # Create helpers namespace for template compatibility
    class Helpers:
        @staticmethod
        def md(text):
            """
            Process text as markdown and remove surrounding '<p>' tags
            simple flat text if possible.
            """
            text = markdown.markdown(text, output_format='html5')
            return re.sub('<p>(.*)?</p>', '\\1', text)
    vars = {**defaults, **data, 'config': config, 'h': Helpers()}
    for filename in os.listdir(theme_dir):
        if filename.endswith('.jinja2'):
            html = render_template(os.path.join(theme_dir, filename), vars)
            with open(os.path.join(output_dir, filename.replace('.jinja2', '.html')), 'wt') as f:
                f.write(html)

def make_html(config, data):
    """Generate static HTML build of the resume."""
    build(data, config)

def make_pdf(config, data):
    """Generate PDF from the rendered HTML."""
    output_dir = config.get('output_dir', 'build')
    HTML(os.path.join(output_dir, 'index.html'), base_url=os.path.join('themes', config['theme'])).write_pdf(
        os.path.join(output_dir, config.get('pdf_file', 'resume.pdf')))

@click.command()
@click.argument('resume_file', type=click.Path(exists=True))
@click.option('-o', '--output_dir', default='build', help='Output directory for the build files.')
@click.option('-f', '--format', default='html', help='Build format (html or pdf).')
@click.option('-t', '--theme', help='Name of the theme to use.')
def main(resume_file, output_dir, format, theme):
    """Generate HTML or PDF resume from YAML file."""
    resume_data = read_yaml(resume_file)
    config = {**resume_data.get('config', {}), 'output_dir': output_dir, 'theme': theme or resume_data.get('config', {}).get('theme', 'simple')}
    {'html': make_html, 'pdf': make_pdf}[format](config, resume_data)

if __name__ == '__main__':
    main()
