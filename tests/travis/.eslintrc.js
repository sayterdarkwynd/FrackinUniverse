'use strict';

module.exports = {
	env: {
		node: true,
		es2021: true
	},
	extends: [
		'wikimedia',
		'wikimedia/node',
		'wikimedia/language/es2021'
	],
	parserOptions: {
		ecmaVersion: 12
	},
	rules: {
		// Necessary to skip: both console.log() and process.exit() are used in tests.
		'no-console': 'off',
		'no-process-exit': 'off',

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
