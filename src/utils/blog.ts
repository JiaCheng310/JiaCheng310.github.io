import type { CollectionEntry } from 'astro:content';

export type BlogEntry = CollectionEntry<'blog'>;

export function sortPosts(posts: BlogEntry[]) {
	return posts.toSorted((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf());
}

export function getUniqueTags(posts: BlogEntry[]) {
	return [...new Set(posts.flatMap((post) => post.data.tags ?? []))].sort((a, b) =>
		a.localeCompare(b),
	);
}

export function slugifyTag(tag: string) {
	return tag
		.toLowerCase()
		.trim()
		.replace(/[^a-z0-9]+/g, '-')
		.replace(/^-+|-+$/g, '');
}
