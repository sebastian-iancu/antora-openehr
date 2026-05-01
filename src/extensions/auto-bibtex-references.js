module.exports.register = function (registry) {
  registry.treeProcessor(function () {
    this.process(function (document) {
      const refsByNumber = new Map();
      const refsInAppearanceOrder = [];
      let hasBibliography = false;
      function markBibliography() {
        hasBibliography = true;
      }

      document.findBy({ traverse_documents: true }, (block) => {
        collectBibliographyState(block.text, refsByNumber, refsInAppearanceOrder, markBibliography);
        collectBibliographyState(block.getTitle && block.getTitle(), refsByNumber, refsInAppearanceOrder, markBibliography);
        if (block.getSourceLines) {
          for (const line of block.getSourceLines()) {
            collectBibliographyState(line, refsByNumber, refsInAppearanceOrder, markBibliography);
          }
        }
        return false;
      });

      if (hasBibliography || (refsByNumber.size === 0 && refsInAppearanceOrder.length === 0)) return document;

      const processor = createTreeProcessorForDocument(document);
      if (!processor) return document;

      processor.citations = refsByNumber.size > 0
        ? Array.from(refsByNumber.entries()).sort(([a], [b]) => a - b).map(([, key]) => key)
        : refsInAppearanceOrder;

      const referencesTitle = document.getAttribute("bibtex-auto-references-title") || "References";
      const list = this.createList(document, "ulist", { title: referencesTitle });
      list.setTitle(referencesTitle);
      document.getBlocks().push(list);
      const children = list.blocks;
      processor.build_bibliography_list().forEach((entry) => {
        children.push(this.createListItem(list, entry));
      });

      return document;
    });
  });
};

function collectBibliographyState(value, refsByNumber, refsInAppearanceOrder, onBibliography) {
  if (typeof value !== "string") return;

  const hasBibliographyMarker = value.includes("[[bibliography_entry_")
    || value.includes('id="bibliography_entry_');
  if (hasBibliographyMarker) {
    onBibliography();
  }

  const xrefPattern = /bibliography_entry_([^,\]#>\s]+)[^\[]*\[(\d+)\]/g;
  let match;
  while ((match = xrefPattern.exec(value))) {
    const key = match[1];
    const number = Number(match[2]);
    if (key && Number.isInteger(number) && !refsByNumber.has(number)) refsByNumber.set(number, key);
  }

  const citePattern = /(?:cite|citenp):[^\[]*\[([^\]]+)\]/g;
  while ((match = citePattern.exec(value))) {
    match[1].split(",").forEach((rawKey) => {
      const key = rawKey.trim().replace(/\([^)]*\)$/, "");
      if (key && !refsInAppearanceOrder.includes(key)) refsInAppearanceOrder.push(key);
    });
  }
}

function createTreeProcessorForDocument(document) {
  const utils = require("@ayowel/asciidoctor-bibtex-js/target/compat/utils").default;
  const { TreeProcessor } = require("@ayowel/asciidoctor-bibtex-js/target/processors/utils/treeprocessor");
  let bibtexFile = document.getAttribute("bibtex-file");
  if (bibtexFile) {
    const relativeBibtexPath = `${document.getBaseDir()}/${bibtexFile}`;
    if (utils.fs.existsSync(relativeBibtexPath)) bibtexFile = relativeBibtexPath;
  }
  if (!bibtexFile) return undefined;

  return new TreeProcessor(
    bibtexFile,
    true,
    document.getAttribute("bibtex-style"),
    document.getAttribute("bibtex-locale"),
    document.getAttribute("bibtex-order") === "appearance",
    document.getAttribute("bibtex-format"),
    document.getAttribute("bibtex-throw", "false") === "true",
    document.getAttribute("bibtex-citation-template") || "[$id]"
  );
}
