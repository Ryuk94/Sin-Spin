# Makefile for Godot Project Dev Workflow

format:
	gdformat .

lint:
	gdlint .

test:
	godot --headless --run-tests --path . > test_output.txt || (cat test_output.txt && exit 1)

check: format lint test
	@echo "✅ All checks passed!"
