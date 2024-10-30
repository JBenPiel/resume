# Include config if exists
-include config.make

# Put these into config.make to override with your setup
RESUME ?= jpiel.yaml

PYTHON ?= $(shell which python3)
BUILD_DIR ?= build/
BUILD_ARGS ?= --output_dir $(BUILD_DIR)
BUILD ?= $(PYTHON) main.py $(BUILD_ARGS)

.PHONY: clean html pdf all

all: clean html pdf

html:
	$(BUILD) --format html resumes/$(RESUME)
	@echo "HTML resume build complete"

pdf:
	$(BUILD) --format pdf resumes/$(RESUME)
	@echo "PDF resume build complete"

clean:
	@rm -rf $(BUILD_DIR)
	@echo "Cleaned build directory"
