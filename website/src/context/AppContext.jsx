import React, { createContext, useContext, useEffect, useState } from 'react';
import { indoreAreas } from '../constants';

const AppContext = createContext();

export const AppProvider = ({ children }) => {
    const [selectedCity, setSelectedCity] = useState(() => {
        const stored = localStorage.getItem('gvx_city');
        // If stored value is not in indoreAreas (e.g. old "Indore - X" format), reset to default
        if (stored && indoreAreas.includes(stored)) return stored;
        return 'Vijay Nagar';
    });

    const [darkMode, setDarkMode] = useState(() => {
        return localStorage.getItem('gvx_dark') === 'true';
    });

    const [appMode, setAppMode] = useState(() => {
        return localStorage.getItem('gvx_appMode') || 'user';
    });

    useEffect(() => {
        localStorage.setItem('gvx_city', selectedCity);
    }, [selectedCity]);

    useEffect(() => {
        localStorage.setItem('gvx_appMode', appMode);
    }, [appMode]);

    useEffect(() => {
        localStorage.setItem('gvx_dark', darkMode);
        if (darkMode) {
            document.documentElement.classList.add('dark');
        } else {
            document.documentElement.classList.remove('dark');
        }
    }, [darkMode]);

    return (
        <AppContext.Provider value={{
            selectedCity,
            setSelectedCity,
            indoreAreas,
            indianCities: indoreAreas,
            darkMode,
            setDarkMode,
            appMode,
            setAppMode
        }}>
            {children}
        </AppContext.Provider>
    );
};

export const useApp = () => useContext(AppContext);
