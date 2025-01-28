## PicdeoSorteo will conveniently sort and rename your random mess of images and videos in sequential numerical order with the format of 0000, 0001, 0002...

Sorting takes into account the "Date taken" property for images and "Media created" property for videos, which are typically used in media timestamps.

**Accepted file formats are :** 
- Images : ".jpg", ".jpeg", ".png", ".tif", ".tiff"
- Videos : ".mp4", ".mov", ".avi", ".mkv", ".wmv"

**Usage** 

Run the following command in powershell

`.\PicdeoSorteo.ps1 -Path "Your Image Folder Path Here"`

**Note** 

If you can't run this script because powershell has blocked scripts (by default), you can temporarily bypass it by the additional keywords in the command below 

`powershell -ExecutionPolicy Bypass -File .\PicdeoSorteo.ps1 -Path "Your Image Folder Path Here"`
