#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix
import pickle
import os
exit(os.getcwd())


# In[2]:


ownership_model = pickle.load(open('C:/Users/Admin/Downloads/svm.pkl', "rb"))


# In[3]:


print("\n*****************************************************")
print("* The USF Super Simple Ownership Prediction Model *")
print("*****************************************************\n")


# In[11]:


Income = float(input("Enter the Income for the predicting ownership: "))
Lot_Size = float(input("Enter the Lot_Size for the predicting Lot Size: "))
df = pd.DataFrame({'Income': [Income],'Lot_Size':[Lot_Size]})

result = ownership_model.predict(df)
probability = ownership_model.predict_proba(df)
ownership = ('Owner', 'Nonowner')

print(f"\n The USF Simple Lawn Mower model indicates probability of ownership is {probability[0][1]:.4f}, therefore it's indicated the user is {result[0]}.\n")


# In[ ]:




