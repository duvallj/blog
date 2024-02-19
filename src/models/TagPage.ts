import type { PageProps } from "./Page";
import type { PostListProps } from "./PostList";

export type TagPageProps = PostListProps &
  PageProps & {
    tag: string;
  };
