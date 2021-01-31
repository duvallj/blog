--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Utils
  ( loadPaginate
  , loadPostData
  , loadTags
  ) where


--------------------------------------------------------------------------------
import           Hakyll
import           Hakyll.Core.Compiler
import           Hakyll.Core.Item
import           Hakyll.Web.Paginate
import           Hakyll.Web.Tags

import           Hakyll.Contrib.BetterPages

import           Control.Monad              (forM)
import           Data.Binary                (Binary)
import           Data.Map                   (elems, keys)
import           Type.Reflection            (Typeable)


--------------------------------------------------------------------------------
-- | Given a Paginate object, return a list of pages that it creates
loadPaginate
  :: (Binary a, Typeable a)
  => Paginate
  -> Compiler [Item a]
loadPaginate pag =
  forM (keys $ paginateMap pag) (load . (paginateMakeId pag))

-- | Given a PostData object (from BetterPages), return a list of Items 
loadPostData
  :: (Binary a, Typeable a)
  => PostData
  -> Compiler [Item a]
loadPostData postdata = 
  forM (elems $ pageMap postdata) load

-- | Given a Tags object, return a list of Items corresponding to the generated
--   pages
loadTags
  :: (Binary a, Typeable a)
  => Tags
  -> Compiler [Item a]
loadTags tags = 
  forM (tagsMap tags) (\(tag, _) -> (load . (tagsMakeId tags)) tag)
