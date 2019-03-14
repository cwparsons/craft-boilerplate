const config = require('./config');
const gulp = require('gulp');
const gutil = require('gulp-util');
const plumber = require('gulp-plumber');
const rev = require('gulp-rev');
const revFormat = require('gulp-rev-format');

module.exports = function (src, dest, opts, failOnError) {
	if (!src) {
		src = [
			`${config.dirs.src}/${config.files.assets}`,
			`!${config.dirs.src}/{assets,cpresources}/**/*`
		];
	}

	if (!dest) {
		dest = './';
	}

	if (!opts) {
		opts = {};
	}

	return gulp.src(src)
		.pipe(plumber())
		.pipe(rev(opts))
		.pipe(revFormat({
			prefix: '.'
		}))
		.pipe(rev.manifest())
		.pipe(gulp.dest(dest))
		.on('end', () => gutil.log('Completed rev task.'));
};
