const path = require('node:path')
const webpack = require('webpack')

const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const RemoveEmptyScriptsPlugin = require('webpack-remove-empty-scripts')
const CopyPlugin = require('copy-webpack-plugin')

const mode = process.env.NODE_ENV === 'development' ? 'development' : 'production'

module.exports = {
  mode,
  devtool: 'source-map',
  entry: {
    application: [
      './app/frontend/application.js'
    ],
    rails_admin: ['./app/javascript/rails_admin.js']
  },
  module: {
    rules: [
      {
        test: /\.(js|ts)$/,
        include: [
          path.resolve(__dirname, 'node_modules/@hotwired/stimulus'),
          path.resolve(__dirname, 'node_modules/@stimulus/polyfills'),
          path.resolve(__dirname, 'node_modules/@rails/actioncable'),
          path.resolve(__dirname, 'app/frontend')
        ],
        use: ['babel-loader']
      },
      {
        test: /\.(png|jpe?g|gif|eot|woff|woff2|ttf|svg|ico)$/i,
        type: 'asset/resource'
      },
      {
        test: /\.(scss|css)/i,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader']
      }
    ]
  },
  resolve: {
    alias: {
      'govuk-frontend-styles': path.resolve(__dirname, 'node_modules/govuk-frontend/dist/govuk/all.scss'),
      'govuk-prototype-styles': path.resolve(__dirname, 'node_modules/@x-govuk/govuk-prototype-components/x-govuk/all.scss'),
      'moj-frontend': path.resolve(__dirname, 'node_modules/@ministryofjustice/frontend/moj/all.js')
    },
    modules: ['node_modules', 'node_modules/govuk-frontend/dist/govuk']
  },
  output: {
    filename: '[name].js',
    // we must set publicPath to an empty value to override the default of
    // auto which doesn't work in IE11
    publicPath: '',
    path: path.resolve(__dirname, 'app/assets/builds')
  },
  plugins: [
    new RemoveEmptyScriptsPlugin(),
    new MiniCssExtractPlugin(),
    new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 }),
    new CopyPlugin({
      patterns: [
        { from: 'node_modules/govuk-frontend/dist/govuk/assets/images', to: 'images' },
        { from: 'node_modules/govuk-frontend/dist/govuk/assets/fonts', to: 'fonts' },
        { from: 'node_modules/html5shiv/dist/html5shiv.min.js', to: 'vendor' },
        { from: 'app/frontend/vendor/outerHTML.js', to: 'vendor' },
        { from: 'app/frontend/vendor/polyfill-output-value.js', to: 'vendor' },
        { from: 'node_modules/@ministryofjustice/frontend/moj/all.js', to: 'vendor' }
      ]
    })
  ]
}
