.PHONY: build help serve

HOST         ?= "0.0.0.0"
PORT         ?= "4000"

.DEFAULT: help

help:
	@echo "Make Help"
	@echo ""
	@echo "make build   - build static files"
	@echo "make serve   - run development server"

serve:
	@bundle exec jekyll serve --host=${HOST} ${PORT}

build:
	@echo ""
	@echo ""
	@echo "Building project..."
	@bundle exec jekyll build
