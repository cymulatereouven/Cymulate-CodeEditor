import { URI } from '../../../../base/common/uri.js';

export type CymulateCodeEditorDirectoryItem = {
	uri: URI;
	name: string;
	isSymbolicLink: boolean;
	children: CymulateCodeEditorDirectoryItem[] | null;
	isDirectory: boolean;
	isGitIgnoredDirectory: false | { numChildren: number }; // if directory is gitignored, we ignore children
}
