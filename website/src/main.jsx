import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App.jsx';
import { AuthProvider } from './context/AuthContext.jsx';
import { AppProvider } from './context/AppContext.jsx';

console.log('main.jsx: Initializing React render...');

ReactDOM.createRoot(document.getElementById('root')).render(
    <React.StrictMode>
        <AppProvider>
            <AuthProvider>
                <App />
            </AuthProvider>
        </AppProvider>
    </React.StrictMode>
);
