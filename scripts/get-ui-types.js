const { download, extract } = require("gitly")
const { dirname, join } = require("path")
const { shx } = require("shx/lib/shx")
const { tmpdir } = require("os")

;(async function main() {
  const source = await download("steelbrain/linter-ui-default")
  const root = dirname(__dirname)
  const distFolder = join(root, "lib", "types", "linter-ui-default")
  shx([, , "rm", "-rf", distFolder])
  // shx([, , "mkdir", "-p", distFolder])

  const extractFolder = join(tmpdir(), "linter-ui-default")
  shx([, , "mkdir", "-p", extractFolder])
  await extract(source, extractFolder)

  shx([, , "mv", join(extractFolder, "dist"), distFolder])
  shx([, , "rm", "-rf", extractFolder])
})()
