export const SITE_TITLE = "Jiacheng's blog";
export const SITE_DESCRIPTION =
	'Minimal notes on engineering, ideas, and quiet work.';
export const SITE_URL = 'https://jiacheng310.github.io/';
export const AUTHOR_NAME = 'Jiacheng Zhang';
export const AUTHOR_HANDLE = '@JiaCheng310';
export const AUTHOR_BIO =
	'Writing about software, machine learning, products, and whatever is worth keeping.';
export const AUTHOR_EMAIL = 'hello@example.com';
export const NAV_LINKS = [
	{ href: '/', label: 'Home' },
	{ href: '/blog', label: 'Archive' },
	{ href: '/tags', label: 'Tags' },
	{ href: '/about', label: 'About' },
] as const;
export const HOME_INTRO = [
	'I use this space for technical essays, research notes, and small observations from building on the web.',
	'The design is intentionally quiet: fast pages, readable typography, and as little friction as possible between an idea and a paragraph.',
];
export const SEARCH_PLACEHOLDER = 'Search posts, tags, and summaries...';

export const COMMENTS = {
	provider: 'giscus',
	enabled: false,
	repo: 'owner/repo',
	repoId: '',
	category: 'General',
	categoryId: '',
	mapping: 'pathname',
	strict: '0',
	reactionsEnabled: '1',
	inputPosition: 'top',
	lang: 'en',
} as const;
