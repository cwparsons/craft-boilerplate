const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const webpack = require('webpack');
const WebpackShellPlugin = require('webpack-shell-plugin');

module.exports = {
	context: __dirname,
	devtool: 'source-map',
	entry: {
		scripts: './web/scripts/scripts.js'
	},
	output: {
		filename: '[name]-bundle.js',
		path: __dirname + '/web/scripts'
	},
	mode: 'production',
	module: {
		rules: [
			{
				test: /\.js$/,
				exclude: /(node_modules|bower_components)/,
				use: {
					loader: 'babel-loader',
					options: {
						presets: ['@babel/preset-env'],
					}
				}
			}
		]
	},
	plugins: [
		new webpack.ProvidePlugin({
			$: 'jquery',
			jQuery: 'jquery'
		}),
		new UglifyJSPlugin({
			sourceMap: true,
			uglifyOptions: {
				output: {
					comments: /^!/
				}
			}
		}),
		new WebpackShellPlugin({ onBuildExit: ['npm run rev'] })
	],
	resolve: {
		alias: {
			jQuery: 'jquery'
		},
		extensions: ['.js', '.jsx']
	}
};
