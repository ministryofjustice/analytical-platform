.PHONY: package preview

.DEFAULT_GOAL := preview

TECH_DOCS_GITHUB_PAGES_PUBLISHER_IMAGE     ?= ghcr.io/ministryofjustice/tech-docs-github-pages-publisher
TECH_DOCS_GITHUB_PAGES_PUBLISHER_IMAGE_SHA ?= sha256:aee182dd1dd86696077ea1c3512590f17ceb9f7a47aa5b16ea4f742666911dbd # v5.0.1

package:
	docker run --rm \
	    --name tech-docs-github-pages-publisher \
	    --volume $(PWD)/config:/tech-docs-github-pages-publisher/config \
		--volume $(PWD)/source:/tech-docs-github-pages-publisher/source \
		$(TECH_DOCS_GITHUB_PAGES_PUBLISHER_IMAGE)@$(TECH_DOCS_GITHUB_PAGES_PUBLISHER_IMAGE_SHA) \
		/usr/local/bin/package

preview:
	docker run -it --rm \
	    --name tech-docs-github-pages-publisher-preview \
	    --volume $(PWD)/config:/tech-docs-github-pages-publisher/config \
		--volume $(PWD)/source:/tech-docs-github-pages-publisher/source \
		--publish 4567:4567 \
		$(TECH_DOCS_GITHUB_PAGES_PUBLISHER_IMAGE)@$(TECH_DOCS_GITHUB_PAGES_PUBLISHER_IMAGE_SHA) \
		/usr/local/bin/preview
