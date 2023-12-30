import type { MarkdownInstance } from "astro";
import type { AstroComponentFactory } from "astro/runtime/server/index.js";
import type { PostProps, Post } from "../models/Post";

interface RawPost {
  title?: string;
  description?: string;
  tags?: string;
}

/**
 * Gets the filename from a complete path
 */
const baseName = (path: string): string => {
  return path.split("\\").pop()!.split("/").pop()!;
};

/**
 * Strips the extension from a filename
 */
const stripExtension = (filename: string): string => {
  return filename.split(".").slice(0, -1).join(".");
};

export interface PostPropsWithComponent extends PostProps {
  Content: AstroComponentFactory;
}

export const getPosts = async (): Promise<PostPropsWithComponent[]> => {
  // Manually type-annotating since vite types refuses to play nice
  /* eslint-disable */
  const rawPosts: Record<string, () => Promise<MarkdownInstance<RawPost>>> =
    import.meta.glob("../posts/*.markdown");
  /* eslint-enable */

  const posts = await Promise.all(
    Object.values(rawPosts).map(async (producer) => {
      const post = await producer();
      const slug = stripExtension(baseName(post.file));
      const title = post.frontmatter.title ?? "untitled";

      const current: Post = {
        slug,
        url: `/posts/${slug}.html`,
        date: new Date(slug.slice(0, 10) + "T12:00:00"),
        title,
        tags: (post.frontmatter.tags ?? "").split(", "),
      };

      const props: PostPropsWithComponent = {
        current,
        title,
        description: post.frontmatter.description,
        Content: post.Content,
      };

      return props;
    }),
  );

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
