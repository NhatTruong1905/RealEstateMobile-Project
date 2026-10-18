export interface Property {
  id: number
  userId?: number
  userFullname?: string
  userEmail?: string
  userPhone?: string
  typeId?: number
  typeName?: string
  categoryId?: number
  categoryName?: string
  title: string
  description?: string
  address?: string
  addressDetail?: string
  city?: string
  price?: number
  area?: number
  floorCount?: number
  bedroomCount?: number
  bathroomCount?: number
  direction?: string
  legal?: string
  status?: string
  images?: string[]
  image?: string
  latitude?: number
  longitude?: number
}

export interface PropertyPage {
  content: Property[]
  currentPage: number
  totalItems: number
  totalPages: number
}

export interface UserProfile {
  id: number
  username: string
  fullname?: string
  email?: string
  phone?: string
  avatar?: string
  roleCode?: string
}

export interface ApiEnvelope<T> { message: string; data?: T }
