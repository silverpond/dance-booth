{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Data.ByteString.Char8 as B8
import qualified Data.ByteString       as B
import           Control.Monad.IO.Class
import           Data.Functor          ((<$>))
import           Snap.Core             (Snap, route, writeBS, dir, logError)
import           Snap.Util.FileServe   (serveDirectory)
import           Snap.Http.Server      (quickHttpServe)
import           Snap.Util.FileUploads
import           System.Posix          (FileOffset, fileSize, getFileStatus)
import           Control.Applicative
import           Data.Monoid
import qualified System.IO.Streams as S
import           System.FilePath
import           Data.String.Conv (toS)
import           Data.Time
import           System.IO


imageDirectory = "../saved-videos"


main :: IO ()
main = quickHttpServe site


site :: Snap ()
site = do
    liftIO $ do
        hSetBuffering stderr LineBuffering
        hSetBuffering stdout LineBuffering

    route [ ("/",         serveDirectory "../ui/dist/")
          , ("/dist",     serveDirectory "../ui/dist/")
          , ("/weights",  serveDirectory "../ui/weights")
          , ("do-upload", doUpload)
          ] 


saveFiles :: (Maybe B.ByteString, B8.ByteString) -> IO ()
saveFiles (Nothing, _)              = return ()
saveFiles (Just file, content)  = do
    time <- show <$> getZonedTime
    let fileName = time <> "-" <> toS file 
    liftIO $ putStrLn $ "[info] Saving file: " <> fileName
    B8.writeFile (imageDirectory </> fileName ) content


doUpload :: Snap ()
doUpload = do
    files <- handleMultipart sanePolicy $ \partInfo stream -> do
        content <- reader stream
        return (partFileName partInfo, content)

    liftIO $ mapM_ saveFiles files

    writeBS . B8.pack . show $ "OK"
  where
    reader stream  = do
        ms <- S.read stream
        case ms of
          Nothing -> pure mempty
          Just s  -> (s <>) <$> reader stream

    sanePolicy = setMaximumFormInputSize size defaultUploadPolicy
    size       = 10 * megaByte
    megaByte   = 2 ^ (10 :: Int)

