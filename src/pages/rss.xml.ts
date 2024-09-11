import rss from "@astrojs/rss";
import type { APIContext } from "astro";
import { getPosts } from "../data/posts";
import sanitizeHtml from "sanitize-html";
import MarkdownIt from "markdown-it";
const parser = new MarkdownIt();

export async function GET(context: APIContext) {
  const posts = await getPosts();
  return rss({
    title: "Jack Duvall's Blog",
    description: "this is a site yes",
    site: context.site ?? "https://blog.duvallj.pw/",
    items: posts
      .map((post) => ({
        link: post.current.url,
        content: sanitizeHtml(parser.render(post.entry.body)),
        title: post.current.title,
        pubDate: post.current.date,
        description: post.frontmatter.description,
        categories: post.current.tags,
      }))
      .reverse(),
    customData: `<language>en-us</language>`,
  });
}
