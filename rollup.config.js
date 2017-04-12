import babel from 'rollup-plugin-babel'
import commonJS from 'rollup-plugin-commonjs'

export default {
  entry: 'lib/index.js',
  dest: 'lib.bundle.js',
  plugins: [
    babel({
      exclude: ['node_modules/**'],
    }),
    commonJS(),
  ],
  format: 'cjs',
  external: ['atom', 'atom-select-list', 'sb-debounce', 'lodash.uniq', 'sb-fs', 'path'],
}
