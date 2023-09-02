{-# LANGUAGE ImportQualifiedPost #-}
--------------------------------------------------------------------------------
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

import Data.List ()
import Data.Map qualified as M
import Data.Maybe ()
import Data.Monoid ()
import GHC.IO.Encoding qualified as E
import Hakyll
import Hakyll.Contrib.BetterArchive
import Hakyll.Contrib.LaTeX
import Hakyll.Contrib.Web.CustomRoutes
import Hakyll.Contrib.Web.TagFormat
import Hakyll.Contrib.Web.TextUtils (firstn)
import Hakyll.Core.Identifier.Pattern ()
import Hakyll.Web.NumberedPostList
import Image.LaTeX.Render
import Image.LaTeX.Render.Pandoc
import System.FilePath (replaceExtension, (</>))
import Utils

--------------------------------------------------------------------------------
main :: IO ()
main = do
  E.setLocaleEncoding E.utf8
  renderLaTeX <- initFormulaCompilerSVG 1000 defaultEnv

  hakyll $ do
    match
      ( "uploads/**"
          .||. "photography/**/*.png"
          .||. "photography/**/*.JPG"
      )
      $ do
        route idRoute
        compile copyFileCompiler

    match "robots.txt" $ do
      route idRoute
      compile copyFileCompiler

    match "uploads/favicon.ico" $ do
      route $ constRoute "favicon.ico"
      compile copyFileCompiler

    match "css/*.css" $ do
      route idRoute
      compile compressCssCompiler

    match (fromList staticPages) $ do
      route $ setExtension "html"
      compile $
        pandocCompiler
          >>= loadAndApplyTemplate "templates/page.html" defaultContext
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    tags <- buildTags postsGlob (fromCapture "tags/*.html")
    let postCtxWithTags = tagsField "tags" tags <> postCtx

    postData <- buildNumberedPostListWith postsGlob sortChronological

    postListRules postData $ \index _ -> do
      route $ setExtension "html"
      compile $ do
        let fullPostCtx = numberedPostContext postData index <> postCtxWithTags

        pandocCompilerWithTransformM
          defaultHakyllReaderOptions
          defaultHakyllWriterOptions
          (renderLaTeX defaultPandocFormulaOptions)
          >>= loadAndApplyTemplate "templates/post.html" fullPostCtx
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    tagsRules tags $ \tag ptrn -> do
      route $ tagRoute tag
      let title = "Posts tagged \"" ++ tag ++ "\""
      compile $ do
        posts <- recentFirst =<< loadAll ptrn
        mainTagsUrl <- urlFromIdentifier "tags.html"
        -- This is a big hack, co-opting the logic to generate a "previous page"
        -- link from pages with actual preivous/next pages. I might want to
        -- split this out into a separate template, but this works too >:)
        let tagCtx =
              constField "title" title
                <> constField "previousPageTitle" "Tags"
                <> constField "previousPageUrl" mainTagsUrl
                <> constField "previousPageNum" "0"
                <> constField "currentPageNum" "1"
                <> listField "posts" postCtxWithTags (return posts)
                <> defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/tag.html" tagCtx
          >>= loadAndApplyTemplate "templates/page.html" tagCtx
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    (archivePages, archiveDates) <- buildArchivePaginateWith archivePageStrategy postsGlob archivePageMaker

    paginateRules archivePages $ \i ptrn -> do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll ptrn
        let archivePageCtx =
              archiveContext archivePages archiveDates archiveTitle i
                <> listField "posts" postCtx (return posts)
                <> dateField "archiveYear" "%Y"
                <> defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/archive-page.html" archivePageCtx
          >>= loadAndApplyTemplate "templates/page.html" archivePageCtx
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    mapM_
      (photoRules . (\i -> "photography/f22-a" ++ i ++ "/"))
      ["1", "2", "3", "4", "5", "6"]

    match "archive.html" $ do
      route idRoute
      compile $ do
        let archivePageIds = map archivePageMaker $ M.elems archiveDates
        archivePageItems <- loadAll $ fromList archivePageIds
        let archivePageItems' = reverseAlphabetical archivePageItems
        let archiveCtx =
              listField "posts" postCtx (return archivePageItems')
                <> defaultContext

        getResourceBody
          >>= applyAsTemplate archiveCtx
          >>= loadAndApplyTemplate "templates/page.html" defaultContext
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    match "tags.html" $ do
      route idRoute
      compile $ do
        tagsBody <- betterRenderTags tags
        let allTagsCtx =
              constField "tags" tagsBody
                <> constField "title" "Tags"
                <> defaultContext

        getResourceBody
          >>= applyAsTemplate allTagsCtx
          >>= loadAndApplyTemplate "templates/page.html" defaultContext
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll postsGlob
        let indexCtx =
              listField "posts" postCtx (return (firstn 10 posts))
                <> defaultContext

        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/page.html" defaultContext
          >>= loadAndApplyTemplate "templates/default.html" indexCtx
          >>= relativizeUrls

    match "sitemap.xml" $ do
      route idRoute
      compile $ do
        postList <- recentFirst =<< loadPostData postData
        tagsList <- loadTags tags
        archiveList <- loadPaginate archivePages
        staticList <- loadAll $ fromList staticPages

        let pagesList = archiveList <> staticList
            sitemapCtx =
              constField "root" root
                <> listField "pages" sitemapPostCtx (return pagesList)
                <> listField "tags" sitemapPostCtx (return tagsList)
                <> listField "posts" sitemapPostCtx (return postList)

        getResourceBody
          >>= applyAsTemplate sitemapCtx

    match "templates/*" $ compile templateBodyCompiler

--------------------------------------------------------------------------------

-- | The root URL of the site
root :: String
root = "https://blog.duvallj.pw"

-- | Static pages
staticPages :: [Identifier]
staticPages = ["about.md", "contact.md", "privacy-policy.md", "photography.md", "friends.md"]

-- | Glob to capture all posts
postsGlob :: Pattern
postsGlob = "posts/*"

-- | Add a date field to the default context
postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y"
    <> defaultContext

-- | Add a sitemap-formatted date and root url
sitemapPostCtx :: Context String
sitemapPostCtx =
  constField "root" root
    <> dateField "date" "%Y-%m-%d"
    <> defaultContext

-- | In a compiler context, get a URL
urlFromIdentifier :: Identifier -> Compiler String
urlFromIdentifier i =
  getRoute i
    >>= \case
      Just r -> return $ toUrl r
      Nothing -> fail ("No URL for page \"" ++ show i ++ "\"")

archiveTitle :: ArchiveDate -> String
archiveTitle date = archiveExtractYear date ++ " archives"

-- | Shorthad for applying the tag rendering found in TagFormat
betterRenderTags :: Tags -> Compiler String
betterRenderTags =
  renderTags formatTagItem formatJoinTags

-- | Make a photography page given a path to photo directory and output html location
photoRules :: FilePath -> Rules ()
photoRules dir = do
  let photoGlob = fromGlob $ dir ++ "*.md"

  match photoGlob $ do
    compile $ pandocCompiler >>= relativizeUrls

  match (fromGlob $ dir ++ "index.html") $ do
    route idRoute
    compile $ do
      photosUnsorted <- loadAll photoGlob
      mainPhotoUrl <- urlFromIdentifier "photography.md"

      let photos = alphabetical photosUnsorted
          photosCtx =
            postCtx <> listField "photos" photoCtx (return photos)
          photoPageCtx =
            defaultContext
              <> constField "previousPageTitle" "Photography Main"
              <> constField "previousPageUrl" mainPhotoUrl
              <> constField "previousPageNum" "0"
              <> constField "currentPageNum" "1"

      getResourceBody
        >>= applyAsTemplate photosCtx
        >>= loadAndApplyTemplate "templates/page.html" photoPageCtx
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

-- | Given an item with some metadata in one field, apply a transformation to
-- create a new field
transformField :: String -> String -> (Identifier -> String -> Compiler String) -> Context String
transformField inField outField transform =
  field outField $ \item -> do
    let ident = itemIdentifier item
    inData <- getMetadataField' ident inField
    transform ident inData

-- | Context for a given photo's metadata
photoCtx :: Context String
photoCtx =
  transformField
    "imgext"
    "imgurl"
    ( \ident ext -> do
        return $ "/uploads" </> replaceExtension (toFilePath ident) ext
    )
    <> postCtx
    <> metadataField
