'use strict';

module.exports = {
	env: {
		node: true,
		es2022: true
	},
	extends: [
		'wikimedia',
		'wikimedia/node',
		'wikimedia/language/es2022'
	],
	rules: {
		// Necessary to skip: both console.log() and process.exit() are used in tests.
		'no-console': 'off',
		'n/no-process-exit': 'off',

		// Unavoidable when loading assets.
		'security/detect-non-literal-fs-filename': 'off',

		// Very annoying with the current codestyle ("for ( var [ a, b ] of ..." loops, etc.).
		'prefer-const': 'off',

		// Only matters for async callbacks, many false positives for synchronous.
		'no-loop-func': 'off',

		// Don't want to apply these.
		'array-bracket-spacing': 'off',
		'computed-property-spacing': 'off',
		'max-len': 'off',
		'no-var': 'off'
	}
};
