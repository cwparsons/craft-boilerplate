const config = require('./config');
const gulp = require('gulp');
const gutil = require('gulp-util');
const rev = require('./rev');
const sasslint = require('./sasslint');
const styles = require('./styles');
const webpack = require('webpack');

module.exports = function () {
	// SCSS files
	gulp.watch(config.files.scss, { cwd: config.dirs.src })
		.on('change', function (file) {
			sasslint(file.path, {}, false);

			styles().on('end', () => rev());
		})
		.on('error', console.log);

	const webpackConfig = require('../webpack.config.js');
	webpackConfig.watch = true;
	webpack(webpackConfig, function (err, stats) {
		if (err) {
			throw new gutil.PluginError('webpack');
		} else {
			gutil.log(stats.toString());
		}
	});
};
