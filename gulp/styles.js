const assets = require('postcss-assets');
const autoprefixer = require('autoprefixer');
const config = require('./config');
const cssnano = require('cssnano');
const gulp = require('gulp');
const gutil = require('gulp-util');
const inlineSvg = require('postcss-inline-svg');
const pixrem = require('pixrem');
const plumber = require('gulp-plumber');
const postcss = require('gulp-postcss');
const sass = require('gulp-sass');
const sourcemaps = require('gulp-sourcemaps');

module.exports = function (src, dest, opts) {
	if (!src) {
		src = [
			`${config.dirs.src}/${config.files.scss}`,
			`!${config.dirs.src}/**/vendor/**/${config.files.scss}`,
			`!${config.dirs.src}/cpresources/**/*`
		];
	}

	if (!dest) {
		dest = config.dirs.src;
	}

	opts = Object.assign({}, opts);

	gutil.log('Starting styles task...');

	const processors = [
		pixrem(),
		autoprefixer({ browsers: ['last 2 versions'] }),
		assets({ loadPaths: ['source/styles'] }),
		inlineSvg(),
		cssnano({ safe: true })
	];

	return gulp.src(src)
		.pipe(plumber())
		.pipe(sourcemaps.init())
		.pipe(sass(opts))
		.on('end', () => gutil.log('\tCompleted sass subtask.'))
		.pipe(postcss(processors))
		.on('end', () => gutil.log('\tCompleted postcss subtask.'))
		.pipe(sourcemaps.write('./'))
		.pipe(gulp.dest(dest))
		.on('end', () => gutil.log('Completed styles task.'));
};
