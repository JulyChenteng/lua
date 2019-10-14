#ifndef _TEST_H
#define _TEST_H

#include <iostream>

using namespace std;

extern "C"
{
    #include <lua.h>
    #include <luablib.h>
    #include <luaxlib.h>
}

class CTest 
{
public:
    CTest() { m_i = 1; m_d = 1.1; }
    
    void Set(int a, double b)
    {
        m_i = a; 
        m_d = b; 
    }

    void Print() { cout << "m_i: " << m_i << ", m_d: " << m_d << endl; }
    
private：
    int m_i;
    double m_d;
};

#endif