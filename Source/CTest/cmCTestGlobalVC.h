/*=========================================================================

  Program:   CMake - Cross-Platform Makefile Generator
  Module:    $RCSfile$
  Language:  C++
  Date:      $Date$
  Version:   $Revision$

  Copyright (c) 2002 Kitware, Inc. All rights reserved.
  See Copyright.txt or http://www.cmake.org/HTML/Copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
#ifndef cmCTestGlobalVC_h
#define cmCTestGlobalVC_h

#include "cmCTestVC.h"

/** \class cmCTestGlobalVC
 * \brief Base class for handling globally-versioned trees
 *
 */
class cmCTestGlobalVC: public cmCTestVC
{
public:
  /** Construct with a CTest instance and update log stream.  */
  cmCTestGlobalVC(cmCTest* ctest, std::ostream& log);

  virtual ~cmCTestGlobalVC();

protected:
  // Implement cmCTestVC internal API.
  virtual bool WriteXMLUpdates(std::ostream& xml);

  /** Represent a vcs-reported action for one path in a revision.  */
  struct Change
  {
    char Action;
    std::string Path;
    Change(char a = '?'): Action(a) {}
  };

  // Update status for files in each directory.
  class Directory: public std::map<cmStdString, File> {};
  std::map<cmStdString, Directory> Dirs;

  // Old and new repository revisions.
  std::string OldRevision;
  std::string NewRevision;

  // Information known about old revision.
  Revision PriorRev;

  // Information about revisions from a svn log.
  std::list<Revision> Revisions;

  virtual const char* LocalPath(std::string const& path);

  virtual void DoRevision(Revision const& revision,
                          std::vector<Change> const& changes);
  virtual void DoModification(PathStatus status, std::string const& path);
  virtual void LoadModifications() = 0;
  virtual void LoadRevisions() = 0;

  void WriteXMLDirectory(std::ostream& xml, std::string const& path,
                         Directory const& dir);
};

#endif