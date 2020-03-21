# medtrees
Online guide to Mediterranean Trees, Shrubs and Climbers

To install on eXist 5.2 with eXide:

download the repository as a zip file
unpack the zip file into a folder

in eXide:

Top menu: File/Manage
You see three subdirectories of db : apps,lib and system 

Ive always put my applications in the apps directry  but I think they could go here instead)

Open the apps directory [ you would think double click left button would do this, but in eXide use CTRL double click left button)

In the apps directory, create a new directory (say medtrees)  - its the icon second left.

Open this new directory

Click the upload files icon (icon third left)

now drag the  unzipped files into the upload area

Click "Done"

The application files should now be in the new directory

To run the application use the url

http://localhost:8080/exist/rest/db/apps/medtrees/guide.xq

You will be prompted to login since the executables are user only 

As currently configured you can add illustrations to an existing species but it lacks the ability to add a species (other than editing mymedlist.xml) . 
It also lacks the ability to include your own photographs

To generate a copy of the site as a single HTML file for public use, especial on a phone, go to "Book"  and ave the single HTML page (with its resources folder) 
