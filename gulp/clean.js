const del = require('del');
const gutil = require('gulp-util');

module.exports = function (src, opts) {
	opts = Object.assign({}, opts);

	return del(src, opts)
		.then(function (paths) {
			if (paths.length) {
				gutil.log(`Deleted files and folders:\n ${paths.join('\n')}`);
			} else {
				gutil.log(`No files to delete.`);
			}
		});
};
