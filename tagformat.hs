--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

module TagFormat (formatTagItem, formatJoinTags) where

import           Data.List (intercalate)

--------------------------------------------------------------------------------

formatTagItem :: String -> String -> Int -> Int -> Int -> String
formatTagItem tag url count _ _ =
  "<span class=\"tag\">" ++ 
  "<a href=\"" ++ url ++ "\" class=\"tag-link\">" ++ 
    tag ++
  "</a> (" ++ show count ++ ")</span>"

formatJoinTags :: [String] -> String
formatJoinTags ss =
  "<ul class=\"tag-list\"><li>" ++
    intercalate "</li><li>" ss ++
  "</li></ul>"
