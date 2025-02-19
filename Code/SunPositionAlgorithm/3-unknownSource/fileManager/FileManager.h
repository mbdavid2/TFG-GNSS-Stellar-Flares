#ifndef FILEMANAGER_H
#define FILEMANAGER_H
#include <iostream>
#include "../auxiliary/Auxiliary.h"

using namespace std;

class FileManager {

	private:
		string inputFile;
		string filteredFile;
		string epochFlare;
		string dataFolder;
		string filterBasicAWKScript;
		string filterTimeAWKScript;

	public:

		void setInputFile(string file);

		void setAWKScripts(string filterBasic, string filterTime);

		possibleSunInfo getCorrectSunLocation();

		int filterTiFileByTime(double time, double time2, double time3);

		void filterUsingAwk(double time);

		void filterTiFileByBasicData();

		void discardOutliersLinearFitFortran(int sigma, int iterations);

		string getFilteredFile();
};

#endif






