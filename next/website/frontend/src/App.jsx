import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './services/AuthContext';
import Navigation from './components/Navigation';
import HomePage from './pages/HomePage';
import BrowsePage from './pages/BrowsePage';
import SubmitPage from './pages/SubmitPage';
import UrshieDetailPage from './pages/UrshieDetailPage';
import DashboardPage from './pages/DashboardPage';

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="min-vh-100 d-flex flex-column">
          <Navigation />
          <main className="flex-grow-1">
            <Routes>
              <Route path="/" element={<HomePage />} />
              <Route path="/browse" element={<BrowsePage />} />
              <Route path="/submit" element={<SubmitPage />} />
              <Route path="/urshie/:id" element={<UrshieDetailPage />} />
              <Route path="/dashboard" element={<DashboardPage />} />
            </Routes>
          </main>
          <footer className="footer">
            <div className="container">
              <div className="row">
                <div className="col-md-6">
                  <p className="mb-0">
                    🐚 Ursh Registry - A community hub for shell scripts
                  </p>
                </div>
                <div className="col-md-6 text-md-end">
                  <a href="https://github.com/day50-dev/ursh" target="_blank" rel="noopener noreferrer" className="me-3">
                    GitHub
                  </a>
                  <a href="https://github.com/day50-dev/ursh/blob/main/README.md" target="_blank" rel="noopener noreferrer">
                    Documentation
                  </a>
                </div>
              </div>
            </div>
          </footer>
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
