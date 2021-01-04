import { createPlugins } from 'rollup-plugin-atomic'

const plugins = createPlugins(['js', ['ts', { tsconfig: './lib/tsconfig.json', noEmitOnError: false, module: 'ESNext' }]])

export default [
  {
    input: 'lib/index.ts',
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
