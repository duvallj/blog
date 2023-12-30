import { getPosts, type PostPropsWithComponent } from "./posts";

/**
 * Sorts all posts into buckets based on year, preserving order
 */
export const getPostsByYear = async (): Promise<
  Map<number, PostPropsWithComponent[]>
> => {
  const posts = await getPosts();
  const output = new Map<number, PostPropsWithComponent[]>();
  posts.forEach((post) => {
    const year = post.current.date.getFullYear();
    const list = output.get(year) ?? [];
    list.push(post);
    output.set(year, list);
  });
  return output;
};
