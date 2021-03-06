--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Maybe  (fromMaybe)
import           Data.Monoid (mappend)
import           Data.List   (concat)
import           Hakyll
import           Hakyll.Contrib.LaTeX
import           Image.LaTeX.Render
import           Image.LaTeX.Render.Pandoc
import qualified GHC.IO.Encoding as E

import           Hakyll.Contrib.BetterPages
import           Hakyll.Contrib.BetterArchive
import           Hakyll.Contrib.Web.CustomRoutes
import           Hakyll.Contrib.Web.TagFormat
import           Hakyll.Contrib.Web.TextUtils (firstn)

import           Utils

--------------------------------------------------------------------------------
main :: IO ()
main = do
  E.setLocaleEncoding E.utf8
  renderLaTeX <- initFormulaCompilerSVG 1000 defaultEnv
  
  hakyll $ do
    match "uploads/**" $ do
      route   idRoute
      compile copyFileCompiler

    match "robots.txt" $ do
      route   idRoute
      compile copyFileCompiler

    match "uploads/favicon.ico" $ do
      route $ constRoute "favicon.ico"
      compile copyFileCompiler

    match "css/*.css" $ do
      route   idRoute
      compile compressCssCompiler

    match (fromList staticPages) $ do
      route   $ setExtension "html"
      compile $ pandocCompiler
        >>= loadAndApplyTemplate "templates/page.html"    defaultContext
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

    tags <- buildTags postsGlob (fromCapture "tags/*.html")
    let postCtxWithTags = tagsField "tags" tags `mappend` postCtx

    postData <- buildPagesWith postsGlob sortChronological  

    pageRules postData $ \index _ -> do
      route $ pageIndexRoute index
      compile $ do
        let fullPostCtx = pageContext postData index `mappend` postCtxWithTags

        pandocCompilerWithTransformM 
          defaultHakyllReaderOptions
          defaultHakyllWriterOptions
          (renderLaTeX defaultPandocFormulaOptions)
          >>= loadAndApplyTemplate "templates/post.html"    fullPostCtx
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    tagsRules tags $ \tag pattern -> do
      route $ tagRoute tag
      let title = "tag \"" ++ tag ++ "\""
      compile $ do
        posts <- recentFirst =<< loadAll pattern
        mainTagsUrl <- urlFromIdentifier "tags.html"
        -- This is a big hack, co-opting the logic to generate a "previous page"
        -- link from pages with actual preivous/next pages. I might want to
        -- split this out into a separate template, but this works too >:)
        let tagCtx = constField "title"  title                              `mappend`
              constField "previousPageTitle" "Tags"                         `mappend`
              constField "previousPageUrl"   mainTagsUrl                    `mappend`
              constField "previousPageNum"   (show 0)                       `mappend` 
              constField "currentPageNum"    (show 1)                       `mappend` 
              listField  "posts"             postCtxWithTags (return posts) `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/tag.html"     tagCtx
          >>= loadAndApplyTemplate "templates/page.html"    tagCtx
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    (archivePages, archiveDates) <- buildArchivePaginateWith archivePageStrategy postsGlob archivePageMaker

    paginateRules archivePages $ \i pattern -> do
      if i == 1
        then route $ composeRoutes (constRoute "archive/index.html") idRoute
        else route idRoute

      compile $ do
        posts <- recentFirst =<< loadAll pattern
        let archiveCtx =
              archiveContext archivePages archiveDates archiveTitle i `mappend` 
              listField "posts" postCtx (return posts)                `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
          >>= loadAndApplyTemplate "templates/page.html"    archiveCtx
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    create ["tags.html"] $ do
      route idRoute
      compile $ do
        tagsBody <- betterRenderTags tags
        let allTagsCtx = 
              constField "tags" tagsBody `mappend`
              constField "title" "Tags"  `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/tag-list.html" allTagsCtx
          >>= loadAndApplyTemplate "templates/page.html"     defaultContext
          >>= loadAndApplyTemplate "templates/default.html"  defaultContext
          >>= relativizeUrls

    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll postsGlob
        let indexCtx =
              listField "posts" postCtx (return (firstn 5 posts)) `mappend`
              defaultContext

        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/page.html"    defaultContext
          >>= loadAndApplyTemplate "templates/default.html" indexCtx
          >>= relativizeUrls

    create ["sitemap.xml"] $ do
      route idRoute
      compile $ do
        postList <- recentFirst =<< loadPostData postData
        tagsList <- loadTags tags
        archiveList <- loadPaginate archivePages
        staticList <- loadAll (fromList staticPages)

        let pagesList = archiveList <> staticList
            sitemapCtx = 
              constField "root" root                              `mappend`
              listField "pages" sitemapPostCtx (return pagesList) `mappend`
              listField "tags"  sitemapPostCtx (return tagsList)  `mappend`
              listField "posts" sitemapPostCtx (return postList)

        makeItem ""
          >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx

    match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
-- | The root URL of the site
root :: String
root = "https://blog.duvallj.pw"

-- | Static pages
staticPages :: [Identifier]
staticPages = ["about.md", "contact.md", "privacy-policy.md"]

-- | Glob to capture all posts
postsGlob :: Pattern
postsGlob = "posts/*"

-- | Add a date field to the default context
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

-- | Add a sitemap-formatted date and root url
sitemapPostCtx :: Context String
sitemapPostCtx = 
  constField "root" root      `mappend`
  dateField "date" "%Y-%m-%d" `mappend`
  defaultContext

-- | In a compiler context, get a URL
urlFromIdentifier :: Identifier -> Compiler String
urlFromIdentifier i = getRoute i
  >>= \maybeRoute ->
    case maybeRoute of
      Just r  -> return $ toUrl r
      Nothing -> fail ("No URL for page \"" ++ show i ++ "\"")

archiveTitle :: ArchiveDate -> String
archiveTitle date = concat [archiveExtractYear date, " archives"]

-- | Shorthad for applying the tag rendering found in TagFormat
betterRenderTags :: Tags -> Compiler String
betterRenderTags =
  renderTags formatTagItem formatJoinTags
