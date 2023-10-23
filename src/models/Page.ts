import type { DefaultProps } from "./Default";

/**
 * Metadata for an arbitrary Page
 */
export type Page = {
  /**
   * URL of the page. Must start with a '/'.
   */
  url: string;
  /**
   * Title of the page.
   */
  title: string;
};

export type PageProps = DefaultProps & {
  inList?: boolean;
  previous?: Page;
  next?: Page;
};
