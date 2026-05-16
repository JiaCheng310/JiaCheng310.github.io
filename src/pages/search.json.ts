import { getCollection } from 'astro:content';
import type { APIRoute } from 'astro';
import { sortPosts } from '../utils/blog';

export const GET: APIRoute = async () => {
	const posts = sortPosts((await getCollection('blog')).filter((post) => !post.data.draft));

	return new Response(
		JSON.stringify(
			posts.map((post) => ({
				title: post.data.title,
				description: post.data.description,
				url: `/blog/${post.id}/`,
				tags: post.data.tags,
				pubDate: post.data.pubDate.toISOString(),
			})),
		),
		{
			headers: {
				'Content-Type': 'application/json; charset=utf-8',
			},
		},
	);
};
