import type { PostProps, Post } from "../models/Post";
import type { CollectionEntry } from "astro:content";
import { getCollection } from "astro:content";

export type PostPropsWithEntry = PostProps & {
  entry: CollectionEntry<"posts">;
};

export const getPosts = async () => {
  const rawPosts = await getCollection("posts");
  const posts: PostPropsWithEntry[] = rawPosts.map((post) => {
    const slug = post.slug;
    const title = post.data.title ?? "untitled";

    const current: Post = {
      url: `/posts/${slug}.html`,
      title,
      slug,
      date: new Date(slug.slice(0, 10) + "T12:00:00"),
      tags: (post.data.tags ?? "").split(", "),
    };

    return {
      entry: post,
      current,
      frontmatter: {
        title,
        description: post.data.description,
      },
    };
  });

  // TODO: do I need to sort first? Seems like it's already sorted by filename which is sorted by date which is what I want roughly

  posts.forEach((post, i) => {
    if (i > 0) {
      post.previous = posts[i - 1]!.current;
    }
    if (i < posts.length - 1) {
      post.next = posts[i + 1]!.current;
    }
  });

  return posts;
};
