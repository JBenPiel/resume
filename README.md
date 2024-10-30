Resume
======

Python resume generator. From YAML to PDF and static HTML in Docker.

# Requirements

* [Docker](https://www.docker.com/)
* To forego using Docker a Python LTS environment is required.

# Installing

1. First, fork this repo!
2. Look at resume examples in the `resumes` folder and create your own.

# Use

## With Docker:

1. After creating a yaml file for you resume you can build and run it as a web service by running `docker compose up --build-arg RESUME=<your_resume.yaml>`.
2. Navigate to `localhost:8080` and view your resume.

### On ECS Fargate:

The `terraform` folder contains IaC for building an ECS cluster and running this project in the least expensive and smallest possible Fargate task. If you wish to use this, adjust what you need in the `main.tf` and `variables.tf` files to fit your needs. Some AWS resources (DynamoDB, ECR, etc.) are not required or are pre-existing and will need to be created beforehand.

## Without Docker:

1. Setup a Python virtual environment using the requirements.txt file.
2. Copy `config.make.example` to `config.make` and update it with your settings.
3. Run `make` to build HTML and PDF files that will go to the `build` directory.

### PDF generation:

A PDF is automatically generated along with HTML when running `make`.
To just create a PDF file you can run: `make pdf`

The PDF file name that is output to the `build` directory is defined by the `pdf_file` property in the `config` section of your resume `yaml` file.

# Customizing

This repo contains a compact, a modern, and a simple theme.

Add your own theme by creating `themes/<your-theme>` folder with `index.jinja2` template file.
Every other (non-jinja2) file from theme directory will be copied to final `build/` destination.

You can control which theme is used by setting `theme` property in the resume's `config` section.

Example Themes:

* [compact](http://jmbeach.github.io/resume/)
* [modern](https://jordan.piel.vip/)
* [simple](http://resume.hanula.com/)

# License

[GNU License](https://gitlab.com/jpiel/resume/-/blob/master/LICENSE)
