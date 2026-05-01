module.exports.register = function () {
  const logger = this.getLogger("patch-asciidoctor-bibtex-lines");
  try {
    const { TreeProcessor } = require("@ayowel/asciidoctor-bibtex-js/target/processors/utils/treeprocessor");
    const proto = TreeProcessor && TreeProcessor.prototype;
    if (!proto) return;

    if (proto.__openEhrBibtexPatched) return;

    const origSearch = proto.search_and_flag_inline_macros;
    const origProcess = proto.process_inline_macros;
    const origBuildBibliographyList = proto.build_bibliography_list;

    proto.search_and_flag_inline_macros = function (line) {
      if (typeof line !== "string") return false;
      return origSearch.call(this, line);
    };

    proto.process_inline_macros = function (line) {
      if (typeof line !== "string") return line;
      return origProcess.call(this, line);
    };

    proto.build_bibliography_list = function () {
      return origBuildBibliographyList.call(this).map((entry, idx) => {
        const key = this.citations && this.citations[idx];
        if (!key || entry.includes(`bibliography_entry_${key}`)) return entry;
        return `[[bibliography_entry_${key}]]${entry}`;
      });
    };

    proto.__openEhrBibtexPatched = true;
    logger.info("Patched asciidoctor-bibtex-js line guards and bibliography anchors");
  } catch (err) {
    logger.warn(`Could not patch asciidoctor-bibtex-js: ${err && err.message ? err.message : err}`);
  }
};
