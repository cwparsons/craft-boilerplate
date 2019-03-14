'use strict';

const clean = require('./gulp/clean');
const config = require('./gulp/config');
const gulp = require('gulp');
const sasslint = require('./gulp/sasslint');
const styles = require('./gulp/styles');
const rev = require('./gulp/rev');
const watch = require('./gulp/watch');

/**
 * Cleaning temporary and build folders.
 */

const _clean = gulp.series(() =>
	clean([
		config.dirs.temp
	])
);


/**
 * Linting.
 */

const _sasslint = gulp.series(() => sasslint());

const _lint = gulp.series(_sasslint);


/**
 * Release build of the project.
 */

const _styles = gulp.series(() => styles());

const _rev = gulp.series(() => rev());

const _production = gulp.series(_clean, _lint, _styles, _rev);


/**
 * Watch.
 */

const _watch = gulp.series(watch);


/**
 * Testing.
 */

const _test = gulp.series(_production, _clean);

module.exports = {
	clean: _clean,
	sasslint: _sasslint,
	lint: _lint,
	styles: _styles,
	rev: _rev,
	production: _production,
	watch: _watch,
	test: _test
};
