import { createPlugins } from 'rollup-plugin-atomic'

const plugins = createPlugins(['js', 'babel'])

export default [
  {
    input: 'lib/index.js',
    output: [
      {
        dir: 'dist',
        format: 'cjs',
        sourcemap: true,
      },
    ],
    // loaded externally
    external: ['atom'],
    plugins,
  },
]
