OrpailleCC_DIR=$(shell pwd)/OrpailleCC
OrpailleCC_INC=$(OrpailleCC_DIR)/src
StreamDM_DIR=$(shell pwd)/streamDM-Cpp
#MOA_DIR=$(shell pwd)/MOA
MOA_DIR=/home/magoa/phd/moa
MOA_COMMAND=java -Xmx512m -cp "$(MOA_DIR)/lib/moa-2019.05.0:$(MOA_DIR)/lib/*" -javaagent:$(MOA_DIR)/lib/sizeofag-1.0.4.jar moa.DoTask
PYTHON_COMMAND=python
ifndef LABEL_COUNT
LABEL_COUNT=33
endif
ifndef FEATURES_COUNT
FEATURES_COUNT=6
endif
ifdef BANOS
BANOS_FLAG=-DBANOS
endif
ifndef MEMORY_SIZE
MEMORY_SIZE=600000
endif
ifdef NN_TRAIN
NN_TRAINING=-DNN_TRAINING
endif
ifndef CXX
CXX=g++
endif
ifdef UNBOUND_OPTIMIZE
UNBOUND_OPTI=-DUNBOUND_OPTIMIZE
endif
SHELL := /bin/bash

ifeq ($(config), debug)
DEBUG_FLAGS= -g -O0 -DDEBUG #$(FLAG_GCOV)
else #release config by default
DEBUG_FLAGS=-O3
endif

COMMON_FLAGS=-std=c++11 -I$(OrpailleCC_INC) -DLABEL_COUNT=$(LABEL_COUNT) -DFEATURES_COUNT=$(FEATURES_COUNT) -DSIZE=$(MEMORY_SIZE) $(NN_TRAINING) $(UNBOUND_OPTI) $(DEBUG_FLAGS) 

ALL_TARGET = empty_classifier previous_classifier \
			 streamdm_ht streamdm_naive_bayes streamdm_perceptron\
			 mondrian_t1 mondrian_t2 mondrian_t3 mondrian_t4 mondrian_t5 \
			 mondrian_t6 mondrian_t7 mondrian_t8 mondrian_t9 mondrian_t10 \
			 mondrian_t11 mondrian_t12 mondrian_t13 mondrian_t14 mondrian_t15 \
			 mondrian_t16 mondrian_t17 mondrian_t18 mondrian_t19 mondrian_t20 \
			 mondrian_t21 mondrian_t22 mondrian_t23 mondrian_t24 mondrian_t25 \
			 mondrian_t26 mondrian_t27 mondrian_t28 mondrian_t29 mondrian_t30 \
			 mondrian_t31 mondrian_t32 mondrian_t33 mondrian_t34 mondrian_t35 \
			 mondrian_t36 mondrian_t37 mondrian_t38 mondrian_t39 mondrian_t40 \
			 mondrian_t41 mondrian_t42 mondrian_t43 mondrian_t44 mondrian_t45 \
			 mondrian_t46 mondrian_t47 mondrian_t48 mondrian_t49 mondrian_t50\
			 mondrian_coarse_rs\
			 mondrian_coarse_acc\
			 mondrian_coarse_kap\
			 mondrian_coarse_racc\
			 mondrian_coarse_rkap\
			 mondrian_coarse_empty\
			 mcnn_c10 mcnn_c20 mcnn_c32 mcnn_c33 mcnn_c34 mcnn_c40 mcnn_c50 \
			 naive_bayes \
			 mlp_3

compile:  $(ALL_TARGET)

mcnn_%: src/main.cpp src/mcnn.cpp
	$(eval clusters=$(shell sed -nr 's/^c([0-9]+)/\1/p' <<< $*))
	$(CXX) src/main.cpp  $(COMMON_FLAGS) $(BANOS_FLAG)\
		-DCLASSIFIER_INITIALIZATION_FILE="\"mcnn.cpp\"" \
		-DMAX_CLUSTERS=$(clusters) -o bin/$@

mondrian_coarse_empty: src/mond_coarse.cpp src/main.cpp
#	$* contains everything within "%" of the target
	$(eval sampling_object=NoMetrics)
	$(CXX) src/main.cpp  $(COMMON_FLAGS) $(BANOS_FLAG) \
		-DCLASSIFIER_INITIALIZATION_FILE="\"mond_coarse.cpp\"" \
		-DSAMPLING_OBJECT="$(sampling_object)" -o bin/$@
mondrian_coarse_rs: src/mond_coarse.cpp src/main.cpp
#	$* contains everything within "%" of the target
	$(eval sampling_object=ReservoirSamplingMetrics)
	$(CXX) src/main.cpp  $(COMMON_FLAGS) $(BANOS_FLAG) \
		-DCLASSIFIER_INITIALIZATION_FILE="\"mond_coarse.cpp\"" \
		-DSAMPLING_OBJECT="$(sampling_object)" -o bin/$@

mondrian_coarse_acc: src/mond_coarse.cpp src/main.cpp
#	$* contains everything within "%" of the target
	$(eval sampling_object=ErrorMetrics<false>)
	$(CXX) src/main.cpp  $(COMMON_FLAGS) $(BANOS_FLAG) \
		-DCLASSIFIER_INITIALIZATION_FILE="\"mond_coarse.cpp\"" \
		-DSAMPLING_OBJECT="$(sampling_object)" -o bin/$@

mondrian_coarse_kap: src/mond_coarse.cpp src/main.cpp
#	$* contains everything within "%" of the target
	$(eval sampling_object=KappaMetrics<$(LABEL_COUNT), false>)
	$(CXX) src/main.cpp  $(COMMON_FLAGS) $(BANOS_FLAG) \
		-DCLASSIFIER_INITIALIZATION_FILE="\"mond_coarse.cpp\"" \
		-DSAMPLING_OBJECT="$(sampling_object)" -o bin/$@

mondrian_coarse_racc: src/mond_coarse.cpp src/main.cpp
#	$* contains everything within "%" of the target
	$(eval sampling_object=ErrorMetrics<true>)
	$(CXX) src/main.cpp  $(COMMON_FLAGS) $(BANOS_FLAG) \
		-DCLASSIFIER_INITIALIZATION_FILE="\"mond_coarse.cpp\"" \
		-DSAMPLING_OBJECT="$(sampling_object)" -o bin/$@

mondrian_coarse_rkap: src/mond_coarse.cpp src/main.cpp
#	$* contains everything within "%" of the target
	$(eval sampling_object=KappaMetrics<$(LABEL_COUNT), true>)
	$(CXX) src/main.cpp  $(COMMON_FLAGS) $(BANOS_FLAG) \
		-DCLASSIFIER_INITIALIZATION_FILE="\"mond_coarse.cpp\"" \
		-DSAMPLING_OBJECT="$(sampling_object)" -o bin/$@

mondrian_t%: src/mond.cpp src/main.cpp
#	$* contains everything within "%" of the target
	$(CXX) src/main.cpp  $(COMMON_FLAGS) $(BANOS_FLAG)\
		-DCLASSIFIER_INITIALIZATION_FILE="\"mond.cpp\"" -DTREE_COUNT=$* -o bin/$@

mondrian_unbound: src/mond_unbound.cpp src/main.cpp
#	$* contains everything within "%" of the target
	$(CXX) src/main.cpp  $(COMMON_FLAGS) $(BANOS_FLAG)\
		-DCLASSIFIER_INITIALIZATION_FILE="\"mond_unbound.cpp\"" -o bin/$@


empty_classifier: src/empty.cpp src/main.cpp
	$(CXX) src/main.cpp $(COMMON_FLAGS) $(BANOS_FLAG) \
		-DCLASSIFIER_INITIALIZATION_FILE="\"empty.cpp\"" -o bin/$@

previous_classifier: src/previous.cpp src/main.cpp
	$(CXX) src/main.cpp $(COMMON_FLAGS) $(BANOS_FLAG) \
		-DCLASSIFIER_INITIALIZATION_FILE="\"previous.cpp\"" -o bin/$@

naive_bayes: src/naive_bayes.cpp src/main.cpp
	$(CXX) src/main.cpp $(COMMON_FLAGS) $(BANOS_FLAG) \
		-DCLASSIFIER_INITIALIZATION_FILE="\"naive_bayes.cpp\"" -o bin/$@

streamdm_ht: src/streamdm_ht.cpp src/main.cpp
	$(CXX) src/main.cpp $(COMMON_FLAGS) $(BANOS_FLAG)\
		-I$(StreamDM_DIR)/code \
		-llog4cpp \
		-pthread \
		-L$(StreamDM_DIR) \
		$(log4cpp) \
		-lstreamdm \
		-DCLASSIFIER_INITIALIZATION_FILE="\"streamdm_ht.cpp\"" -o bin/$@ 
streamdm_naive_bayes: src/streamdm_naive_bayes.cpp src/main.cpp
	$(CXX) src/main.cpp $(COMMON_FLAGS) $(BANOS_FLAG)\
		-I$(StreamDM_DIR)/code \
		-llog4cpp \
		-pthread \
		-L$(StreamDM_DIR) \
		$(log4cpp) \
		-lstreamdm \
		-DCLASSIFIER_INITIALIZATION_FILE="\"streamdm_naive_bayes.cpp\"" -o bin/$@ 
streamdm_perceptron: src/streamdm_ht.cpp src/main.cpp
	$(CXX) src/main.cpp $(COMMON_FLAGS) $(BANOS_FLAG)\
		-I$(StreamDM_DIR)/code \
		-llog4cpp \
		-pthread \
		-L$(StreamDM_DIR) \
		$(log4cpp) \
		-lstreamdm \
		-DCLASSIFIER_INITIALIZATION_FILE="\"streamdm_perceptron.cpp\"" -o bin/$@ 

mlp_%: src/neural_network.cpp src/main.cpp
	$(CXX) src/main.cpp  $(COMMON_FLAGS) $(BANOS_FLAG)\
		-DCLASSIFIER_INITIALIZATION_FILE="\"neural_network.cpp\"" -DLAYER_COUNT=$* -o bin/$@
latex:
	$(PYTHON_COMMAND) makefile.py latex
dataset:
	$(PYTHON_COMMAND) makefile.py dataset
	shuf /tmp/processed_subject1_ideal.log > /tmp/processed_subject1_ideal_shuf.log
run:
	$(PYTHON_COMMAND) makefile.py run
rerun: 
	rm -f /tmp/output /tmp/output_runs models.csv
	$(PYTHON_COMMAND) makefile.py run
calibration: 
	$(PYTHON_COMMAND) makefile.py calibration
xp0: empty_classifier previous_classifier \
			 streamdm_ht streamdm_naive_bayes streamdm_perceptron\
			 mondrian_t1 mondrian_t2 mondrian_t3 mondrian_t4 mondrian_t5 \
			 mondrian_t6 mondrian_t7 mondrian_t8 mondrian_t9 mondrian_t10 \
			 mondrian_t11 mondrian_t12 mondrian_t13 mondrian_t14 mondrian_t15 \
			 mondrian_t16 mondrian_t17 mondrian_t18 mondrian_t19 mondrian_t20 \
			 mondrian_t21 mondrian_t22 mondrian_t23 mondrian_t24 mondrian_t25 \
			 mondrian_t26 mondrian_t27 mondrian_t28 mondrian_t29 mondrian_t30 \
			 mondrian_t31 mondrian_t32 mondrian_t33 mondrian_t34 mondrian_t35 \
			 mondrian_t36 mondrian_t37 mondrian_t38 mondrian_t39 mondrian_t40 \
			 mondrian_t41 mondrian_t42 mondrian_t43 mondrian_t44 mondrian_t45 \
			 mondrian_t46 mondrian_t47 mondrian_t48 mondrian_t49 mondrian_t50\
			 mcnn_c10 mcnn_c20 mcnn_c32 mcnn_c33 mcnn_c34 mcnn_c40 mcnn_c50 \
			 naive_bayes \
			 mlp_3
xp1: empty_classifier mondrian_t1 mondrian_t5 mondrian_t10 mondrian_t50 mondrian_coarse_empty
xp2: empty_classifier mondrian_t1 mondrian_t5 mondrian_t10 mondrian_t50 mondrian_coarse_empty
moa_xp0:
	cd $(MOA_DIR)
	#We set the random seed to 888
	$(MOA_COMMAND) "WriteStreamToARFFFile -s (generators.HyperplaneGenerator -a 3 -k 0 -i 888) -f dataset_1.arff -m 200000"
	$(MOA_COMMAND) "WriteStreamToARFFFile -s (generators.RandomRBFGenerator -r 777 -i 888 -a 3 -n 20) -f dataset_2.arff -m 200000"
	$(MOA_COMMAND) "WriteStreamToARFFFile -s (generators.RandomTreeGenerator -r 777 -i 888 -c 10 -o 0 -u 6 -d 10 -l 5) -f dataset_3.arff -m 200000"
	 sed 's/,class1,/,0/g' dataset_1.arff | sed 's/,class2,/,1/g' | sed 's/,/	/g' > dataset_1.log
	 sed 's/,class1,/,0/g' dataset_2.arff | sed 's/,class2,/,1/g' | sed 's/,/	/g' > dataset_2.log
	 sed 's/,class10,/,9/g' dataset_3.arff | sed 's/,class1,/,0/g' | sed 's/,class2,/,1/g' | sed 's/,class3,/,2/g' | sed 's/,class4,/,3/g' | sed 's/,class5,/,4/g' | sed 's/,class6,/,5/g' | sed 's/,class7,/,6/g' | sed 's/,class8,/,7/g' | sed 's/,class9,/,8/g' | sed 's/,/	/g' > dataset_3.log
	 cp dataset_*.log /tmp
moa_xp1_xp2:
	cd $(MOA_DIR)
	$(MOA_COMMAND) "WriteStreamToARFFFile -s (generators.RandomRBFGeneratorDrift -s 0.001 -c 33 -a 12 -r 1 -i 1) -f RandomRBF_drift.artf -m 20000"
	$(MOA_COMMAND) "WriteStreamToARFFFile -s (generators.RandomRBFGenerator -c 33 -a 12 -r 1 -i 1) -f RandomRBF_stable.artf -m 20000"
	sed 's/class\([0-9]*\)/\1/' RandomRBF_drift.artf | sed 's/,/	/g' | tail -n +19 > RandomRBF_drift.log
	sed 's/class\([0-9]*\)/\1/' RandomRBF_stable.artf | sed 's/,/	/g' | tail -n +19 > RandomRBF_stable.log
plot_results:
	PYTHONHASHSEED=0 $(PYTHON_COMMAND) makefile.py plot_results
plot_hyperparameters:
	PYTHONHASHSEED=0 $(PYTHON_COMMAND) makefile.py plot_hyperparameters
clean:
	rm -rf bin/mondrian_t* bin/empty_classifier bin/previous_classifier bin/mcnn_* bin/streamdm_ht bin/streamdm_perceptron bin/streamdm_naive_bayes bin/naive_bayes
