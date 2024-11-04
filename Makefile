# Include config if exists
-include config.make

# Default values (can be overridden in config.make)
RESUME ?= jpiel.yaml
PYTHON ?= python3
BUILD_DIR ?= build/
BUILD_ARGS ?= --output_dir $(BUILD_DIR)
BUILD_CMD ?= $(PYTHON) main.py $(BUILD_ARGS)

.PHONY: clean html pdf all

# Target to build all formats
all: clean html pdf

# Build HTML format
html:
	$(BUILD_CMD) --format html resumes/$(RESUME)
	@echo "HTML resume build complete"

# Build PDF format
pdf:
	$(BUILD_CMD) --format pdf resumes/$(RESUME)
	@echo "PDF resume build complete"

# Clean the build directory
clean:
	@rm -rf $(BUILD_DIR)
	@echo "Cleaned build directory"
