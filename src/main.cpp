#include <fstream>
#include <iostream>
#include <string>
#include <sstream>
#include <cmath>
#include "utils.hpp"

#define MACRO_F1 0
#define WEIGHTED_F1 1

using namespace std;


class functions{
	public:
	static void* malloc(int const size){
		return std::malloc(size);
	}
	static void free(void* p){
		std::free(p);
	}
	static double log(double const x){
		return std::log(x);
	}
	static double log2(double const x){
		return std::log2(x);
	}
	static double exp(double const x){
		return std::exp(x);
	}
	static double sqrt(double const x){
		return std::sqrt(x);
	}
	static bool isnan(double const x){
		return std::isnan(x);
	}
	//TODO: we need a rand_uniform and a log functions (log == ln)
	static double rand_uniform(void){
		return static_cast<double>(rand()%RAND_MAX)/static_cast<double>(RAND_MAX);
	}
	static double random(void){
		return (static_cast<double>(std::rand()%RAND_MAX) / static_cast<double>(RAND_MAX));
	}
	template<class T>
	static int round(T const x){
		return std::round(x);
	}
	template<class T>
	static int floor(T const x){
		return std::floor(x);
	}
	static double activation(double input){
		return 1.0 / (1 + exp(-input));
	}
	static double derivative(double const x){
		return x * (1 - x);
	}
};


#include CLASSIFIER_INITIALIZATION_FILE

template<int label_count>
class Evaluation{
	double counts[label_count+1][label_count+1];
	double fading_factor;
	public:
		Evaluation(double const fading_factor){
			this->fading_factor = fading_factor;
			for(int i = 0; i <= label_count; ++i)
				for(int j = 0; j <= label_count; ++j)
						counts[i][j] = 0;
		}
		void count(int const prediction, int const label){
			for(int i = 0; i <= label_count; ++i)
				for(int j = 0; j <= label_count; ++j)
					counts[i][j] *= fading_factor;

			counts[prediction][label] += 1;
			counts[label_count][label] += 1;
			counts[prediction][label_count] += 1;
			counts[label_count][label_count] += 1;
		}
		double accuracy(void) const{
			double right = 0;
			for(int i = 0; i < label_count; ++i)
				right += counts[i][i];
			double const total = counts[label_count][label_count];
			return right / total;
		}
		double f1(int const type=MACRO_F1, bool print=false) const{
			if(type == MACRO_F1)
				return macro_f1(print);
			else
				return weighted_f1(print);
		}
		double macro_f1(bool print=false) const{
			double score_sum = 0;
			unsigned int count = 0;
			double f1s[label_count];
			double support[label_count];
			f1_per_class(f1s);
			support_per_class(support);
			for(int i = 0; i < label_count; ++i){
				if(support[i] > 0){ //The label has to have been encountered
					count += 1;
					score_sum += f1s[i];
				}
			}
			if(count == 0)
				return 0;
			return score_sum / static_cast<double>(count);
		}
		double weighted_f1(bool print=false) const{
			double score = 0;
			double f1s[label_count];
			double support[label_count];
			f1_per_class(f1s);
			support_per_class(support);
			for(int i = 0; i < label_count; ++i){
					score += f1s[i] * support[i];
			}
			return score;
		}
		void f1_per_class(double * f1s) const{
			for(int i = 0; i < label_count; ++i){
				if(counts[label_count][i] != 0){ //The label has to have been encountered
					double const precision = counts[i][label_count] == 0 ? 1 : counts[i][i] / counts[i][label_count];
					double const recall = counts[i][i] / counts[label_count][i];
					if((precision + recall) != 0 && !(isnan(precision) && isnan(recall))){
						double const score = 2 * ((precision * recall) / (precision + recall));
						f1s[i] = score;
					}
					else{
						f1s[i] = 0;
					}
				}
				else{
					f1s[i] = 0;
				}
			}
		}
		void recall_per_class(double * rec) const{
			for(int i = 0; i < label_count; ++i){
				if(counts[label_count][i] != 0){ //The label has to have been encountered
					double const recall = counts[i][i] / counts[label_count][i];
					rec[i] = recall;
				}
				else{
					rec[i] = 0;
				}
			}
		}
		void support_per_class(double * support) const{
			double sum = 0;
			for(int i = 0; i < label_count; ++i){
				sum += counts[label_count][i];
				support[i] = counts[label_count][i];
			}
			if(sum > 0){
				for(int i = 0; i < label_count; ++i){
					support[i] = support[i] / sum;
				}
			}
		}
};

template<int feature_count, int label_count, class func, class C, class E>
int process_file(int const model_id, int const run_id, int const seed, string const filename, C* classifier, E* evaluator){
	ifstream myfile, statm;
	string line;
	myfile.open (filename);
	if(!myfile.is_open()){
		return 1;
	}
	statm.open("/proc/self/statm");
	if(!myfile.is_open()){
		return 2;
	}
	int line_count = 1;
	int* stats = new int[label_count];
	bool seen_label[label_count] = {0};
	for(int i = 0; i < label_count; ++i)
		seen_label[i] = false;

	//Start reading the file
	while (getline (myfile,line) ) {
		double features[feature_count+1]; //+1 because we need the label
		parse_line<feature_count+1>(line, features);
		int label = func::round(features[feature_count]);
		features[feature_count] = 0;
#ifdef BANOS
		if(label > 0){
			label -= 1; //We removed the zero
#endif
#ifndef NN_TRAINING
			int const prediction = classifier->predict(features);
			if(seen_label[label]){
				evaluator->count(prediction, label);
			}
			else{
				seen_label[label] = true;
			}
#endif
			classifier->train(features, label);
#ifndef NN_TRAINING
			line_count += 1;
			if(line_count%50 == 0){
				double const f = evaluator->f1(MACRO_F1);
				cout << model_id << "," << run_id << "," << line_count << "," << seed << "," << evaluator->accuracy() << "," << f << ",";
				//rewind cursor
				statm.seekg(0, ios::beg);
				char letter = 'A';
				while(letter != ' '){
					statm.read(&letter, 1);
					if(letter != ' ')
						cout << letter;
				}
				cout << endl;
			}
			else if(line_count%50 == 0){
				cout << model_id << "," << run_id << "," << line_count << "," << seed << "," << evaluator->accuracy() << "," << evaluator->f1(MACRO_F1) << "," << endl;
			}
#endif
#ifdef BANOS
		}
#endif
	}
	myfile.close();
	return line_count;
}

int main(int argc, char** argv){

	if(argc < 5){
		cout << "usage: " << argv[0] << " <file1> <seed> <model id> <run id> <parameter classifier ...>" << endl;
		return 0;
	}
	char* filename = argv[1];
	int const seed = stoi(argv[2]);
	int const model_id = stoi(argv[3]);
	int const run_id = stoi(argv[4]);
	Evaluation<LABEL_COUNT> evaluator(0.995); //magic number from issue with data stream learning
	//Evaluation<LABEL_COUNT> evaluator(1.0);
	auto classifier = get_classifier(seed, argc-5, argv+5);
	if(classifier != nullptr){
#ifdef NN_TRAINING
		while(classifier->err() > 0.000001)
#endif
			int datapoint_count = process_file<FEATURES_COUNT, LABEL_COUNT, functions>(model_id, run_id, seed, filename, classifier, &evaluator);
	}
	delete classifier;
	return 0;
}

