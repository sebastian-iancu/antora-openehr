const fs = require('fs')
const yaml = require('js-yaml')
const path = require('path')

function interpolateAttributes(attributes, logger) {
    const resolved = {}
    const maxIterations = 10

    Object.assign(resolved, attributes)

    for (let iteration = 0; iteration < maxIterations; iteration++) {
        let changed = false
        for (const [key, value] of Object.entries(resolved)) {
            if (typeof value === 'string') {
                const newValue = value.replace(/\{([^}]+)\}/g, (match, attrName) => {
                    if (resolved[attrName] !== undefined) {
                        changed = true
                        return resolved[attrName]
                    }
                    logger.warn(`Attribute reference {${attrName}} in ${key} could not be resolved`)
                    return match
                })
                resolved[key] = newValue
            }
        }

        if (!changed) break
    }

    // Check for circular references
    for (const [key, value] of Object.entries(resolved)) {
        if (typeof value === 'string' && value.includes('{')) {
            logger.warn(`Unresolved attribute references in ${key}: ${value}`)
        }
    }

    return resolved
}

module.exports.register = function ({config, playbook}) {
    const logger = this.getLogger('load-global-vars')

    this.once('playbookBuilt', ({playbook}) => {
        const extCfg = (playbook.antora && playbook.antora.extensions) || []

        // Find the extension config block (by "require" path match)
        const myCfg = extCfg.find((e) => e.require && e.require.includes('load-global-vars.js')) || {}
        logger.info(`Found config for global-vars: ${JSON.stringify(myCfg)}`)
        // extract attributes file path
        const files = myCfg.varFiles || [myCfg.varFiles].filter(Boolean)
        logger.info(`Required files for global-vars: ${JSON.stringify(files)}`)

        // load global-vars as attributes
        let attributes = {}
        for (const f of files) {
            const attributesFile = path.resolve(process.cwd(), f)
            logger.info(`Located ${f} as ${attributesFile} file of global-vars to load`)
            if (!fs.existsSync(attributesFile)) {
                logger.warn(`Globals file not found: ${attributesFile}`)
                continue
            }
            const obj = yaml.load(fs.readFileSync(attributesFile, 'utf8')) || {}
            logger.info(`Loaded ${Object.keys(obj).length} attributes from ${attributesFile} file`)
            attributes = Object.assign(attributes, obj)
        }
        logger.info(`Loaded ${Object.keys(attributes).length} attributes as global-vars`)

        try {
            const resolvedAttributes = interpolateAttributes(attributes, logger)

            if (!playbook.asciidoc.attributes) {
                playbook.asciidoc.attributes = {}
            }

            Object.assign(playbook.asciidoc.attributes, resolvedAttributes)

            logger.info(`Loaded ${Object.keys(resolvedAttributes).length} attributes as global-vars`)
        } catch (err) {
            logger.error(`Failed to load attributes: ${err.message}`)
        }
    })
}