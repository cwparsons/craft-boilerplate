const config = require('./config');
const gulp = require('gulp');
const plumber = require('gulp-plumber');
const sasslint = require('gulp-sass-lint');

module.exports = function (src, opts, failOnError) {
	if (!src) {
		src = [
			`${config.dirs.src}/${config.files.scss}`,
			`!${config.dirs.src}/**/vendor/**/${config.files.scss}`,

			// Images uses syntax not readable with sasslint
			'!**/reference/_images.scss'
		];
	}

	if (!opts) {
		opts = {};
	}

	opts = Object.assign({
		configFile: 'sasslint.yml'
	}, opts);

	return gulp.src(src)
		.pipe(plumber())
		.pipe(sasslint(opts))
		.pipe(sasslint.format())
		.pipe(sasslint.failOnError());
};
