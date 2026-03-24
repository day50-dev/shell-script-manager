import { useState, useEffect } from 'react';
import { Container, Row, Col, Form, InputGroup, Button } from 'react-bootstrap';
import { useSearchParams } from 'react-router-dom';
import { urshiesAPI } from '../services/api';
import UrshieCard from '../components/UrshieCard';
import LoadingSpinner from '../components/LoadingSpinner';
import AlertMessage from '../components/AlertMessage';
import { FiSearch, FiFilter } from 'react-icons/fi';

function BrowsePage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [urshies, setUrshies] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [pagination, setPagination] = useState({ page: 1, totalPages: 1, total: 0 });
  const [tags, setTags] = useState([]);

  const search = searchParams.get('search') || '';
  const tag = searchParams.get('tag') || '';
  const page = parseInt(searchParams.get('page')) || 1;

  useEffect(() => {
    fetchUrshies();
    fetchTags();
  }, [search, tag, page]);

  const fetchUrshies = async () => {
    try {
      setLoading(true);
      const response = await urshiesAPI.getAll({ search, tag, page, limit: 12 });
      setUrshies(response.data.data);
      setPagination(response.data.pagination);
      setError(null);
    } catch (err) {
      setError('Failed to load urshies');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchTags = async () => {
    try {
      const response = await urshiesAPI.getTags();
      setTags(response.data);
    } catch (err) {
      console.error('Failed to load tags:', err);
    }
  };

  const handleSearch = (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const newSearch = formData.get('search');
    setSearchParams({ search: newSearch, page: 1 });
  };

  const handleTagClick = (selectedTag) => {
    if (tag === selectedTag) {
      setSearchParams({ search, page: 1 });
    } else {
      setSearchParams({ search, tag: selectedTag, page: 1 });
    }
  };

  const handlePageChange = (newPage) => {
    setSearchParams({ search, tag, page: newPage });
  };

  if (loading && urshies.length === 0) {
    return <LoadingSpinner text="Loading urshies..." />;
  }

  return (
    <Container className="py-4">
      <Row className="mb-4">
        <Col>
          <h2>Browse Urshies</h2>
          <p className="text-muted">Discover shell scripts shared by the community</p>
        </Col>
      </Row>

      {/* Search and Filter */}
      <Row className="mb-4">
        <Col lg={8}>
          <Form onSubmit={handleSearch}>
            <InputGroup>
              <InputGroup.Text>
                <FiSearch />
              </InputGroup.Text>
              <Form.Control
                name="search"
                defaultValue={search}
                placeholder="Search by name, description, or URL..."
              />
              <Button type="submit" variant="primary">Search</Button>
            </InputGroup>
          </Form>
        </Col>
        {tag && (
          <Col lg={4} className="d-flex align-items-center">
            <span className="text-muted">Filtering by tag:</span>
            <Button
              variant="outline-primary"
              size="sm"
              className="ms-2"
              onClick={() => handleTagClick(tag)}
            >
              {tag} ×
            </Button>
          </Col>
        )}
      </Row>

      {/* Tags */}
      {tags.length > 0 && (
        <Row className="mb-4">
          <Col>
            <div className="d-flex align-items-center flex-wrap gap-2">
              <FiFilter className="text-muted" />
              <span className="text-muted">Popular tags:</span>
              {tags.slice(0, 10).map((tagItem) => (
                <Button
                  key={tagItem.tag}
                  variant={tag === tagItem.tag ? 'primary' : 'outline-secondary'}
                  size="sm"
                  onClick={() => handleTagClick(tagItem.tag)}
                >
                  {tagItem.tag} ({tagItem.count})
                </Button>
              ))}
            </div>
          </Col>
        </Row>
      )}

      {error && <AlertMessage variant="danger" message={error} />}

      {/* Urshies Grid */}
      {loading ? (
        <LoadingSpinner text="Loading..." />
      ) : urshies.length === 0 ? (
        <Row>
          <Col>
            <div className="text-center py-5">
              <h4>No urshies found</h4>
              <p className="text-muted">
                {search || tag
                  ? 'Try adjusting your search or filters'
                  : 'Be the first to submit an urshie!'}
              </p>
              {!search && !tag && (
                <a href="/submit" className="btn btn-primary">Submit Urshie</a>
              )}
            </div>
          </Col>
        </Row>
      ) : (
        <>
          <Row className="g-4">
            {urshies.map((urshie) => (
              <Col key={urshie.id} md={6} lg={4}>
                <UrshieCard urshie={urshie} />
              </Col>
            ))}
          </Row>

          {/* Pagination */}
          {pagination.totalPages > 1 && (
            <Row className="mt-4">
              <Col className="d-flex justify-content-center">
                <nav>
                  <ul className="pagination">
                    <li className={`page-item ${page === 1 ? 'disabled' : ''}`}>
                      <button
                        className="page-link"
                        onClick={() => handlePageChange(page - 1)}
                        disabled={page === 1}
                      >
                        Previous
                      </button>
                    </li>
                    {Array.from({ length: pagination.totalPages }, (_, i) => i + 1).map((p) => (
                      <li key={p} className={`page-item ${page === p ? 'active' : ''}`}>
                        <button className="page-link" onClick={() => handlePageChange(p)}>
                          {p}
                        </button>
                      </li>
                    ))}
                    <li className={`page-item ${page === pagination.totalPages ? 'disabled' : ''}`}>
                      <button
                        className="page-link"
                        onClick={() => handlePageChange(page + 1)}
                        disabled={page === pagination.totalPages}
                      >
                        Next
                      </button>
                    </li>
                  </ul>
                </nav>
              </Col>
            </Row>
          )}
        </>
      )}
    </Container>
  );
}

export default BrowsePage;
