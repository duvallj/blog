import { defineCollection } from "astro:content";
import { rssSchema } from "@astrojs/rss";

const posts = defineCollection({
  type: "content",
  schema: rssSchema,
});

export const collections = {
  posts,
};
